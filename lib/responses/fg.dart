import 'package:flutter/material.dart';

class HoodTest extends StatefulWidget {
  const HoodTest({super.key});

  @override
  State<HoodTest> createState() => _HoodTestState();
}

class _HoodTestState extends State<HoodTest> {
  @override
  Widget build(BuildContext context) {
   return BlocBuilder<CompanyCubit, CompanyState>(
      builder: (context, companyState) {
        if (companyState is CompanyLoaded) {
          List<CompanyInfo> companyList = companyState.companyList;

          Map<String, String> companyNameToId = {
            for (var company in companyList)
              company.companyName: company.companyId
          };

          List<String> companyNames = companyList.map((e) => e.companyName).toList();

          // Lazy loading variables
          int start = 1;
          final int length = 10;
          bool hasMore = true;
          List<String> allCompanyNames = [];
          bool isFetching = false;

          Future<List<String>> fetchCompanies(String? filter) async {
            if (!hasMore || isFetching) return allCompanyNames;

            isFetching = true;
            final response = await http.post(
              Uri.parse(AdminCS().getAllCompaniesApi),
              headers: {
                'authorization': 'Basic ${base64Encode(utf8.encode('${AdminCS().username}:${AdminCS().password}'))}',
                'authtoken': await SharedPreferences.getInstance().then((prefs) => prefs.getString('user_token') ?? ''),
                'x-api-key': AdminCS().apiKey,
              },
              body: {
                'start': '$start',
                'length': '$length',
                'clients[]': 'all',
                'entity_status[]': '',
              },
            );

            isFetching = false;

            if (response.statusCode == 200) {
              final responseData = json.decode(response.body);
              final List companyList = responseData['data']['data']['companyinfo'];

              final List<String> newCompanies = companyList
                  .map((e) => e['company_name'] as String)
                  .where((name) => filter == null || name.toLowerCase().contains(filter.toLowerCase()))
                  .toList();

              allCompanyNames.addAll(newCompanies);
              start += length;

              if (newCompanies.length < length) {
                hasMore = false;
              }

              return allCompanyNames;
            } else {
              throw Exception('Failed to load companies');
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Company",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF757784),
                ),
              ),
              const SizedBox(height: 8),
              DropdownSearch<String>(
                asyncItems: (String? filter) => fetchCompanies(filter),
                selectedItem: selectedCompany,
                onChanged: (value) {
                  context.read<CompanyCubit>().setSelectedCompany(
                    name: value,
                    id: companyNameToId[value] ?? '',
                  );
                  selectedCompany = value;
                  selectedCompanyId = companyNameToId[value!] ?? '';
                },
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: const InputDecoration(
                      hintText: 'Search company...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  itemBuilder: (context, item, isSelected) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(item, style: const TextStyle(fontSize: 16)),
                  ),
                  scrollbarProps: const ScrollbarProps(
                    isAlwaysShown: true,
                    thickness: 4,
                  ),
                ),
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ),
                dropdownButtonProps: const DropdownButtonProps(
                  icon: Icon(Icons.keyboard_arrow_down),
                ),
              ),
            ],
          );
        } else if (companyState is CompanyLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (companyState is CompanyError) {
          return Text("Error: ${companyState.error}");
        } else {
          return const Text("No companies available");
        }
      },
    );
  }
}
